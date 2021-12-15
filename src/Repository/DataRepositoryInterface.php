<?php declare(strict_types=1);

namespace App\Repository;

interface DataRepositoryInterface
{
    public function insert(array $data): bool;

    public function findAll(): array;

    public function getNewestDate(): \DateTimeInterface;
}
